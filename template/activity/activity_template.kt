package ${PACKAGE_NAME}

import android.content.Intent
import androidx.activity.viewModels
import ${applicationId}.R
import ${applicationId}.BR
import ${applicationId}.databinding.Activity${NAME}Binding
import com.studio.common.ui.base.BaseBindingActivity
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class ${NAME}Activity : BaseBindingActivity<${NAME}ViewModel, Activity${NAME}Binding>() {
    override fun getViewModelBindingVariable(): Int = BR.viewModel

    override val viewModel by viewModels<${NAME}ViewModel>()

    override val layoutId: Int = R.layout.activity_${lower_name}

    override fun initData(
        intent: Intent?,
        isNewIntent: Boolean
    ) {
        Unit
    }

    override fun initViewModel() {
        Unit
    }
}